// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Repo {

/// 仓库全路径（owner/name），详情与跳转的唯一标识。
 String get path;/// 仓库名（path 的最后一段）。
 String get name;/// 简介。
 String? get description;/// 主语言（`AppLanguageColors` 色条依据）。
 String? get language;/// star 数。
 int get starCount;/// fork 数。
 int get forkCount;/// 开放 Issue 数。
 int get openIssueCount;/// 开放 PR 数。
 int get openPullRequestCount;/// 开源协议。
 String? get license;/// 最后更新者用户名。
 String? get lastUpdateUsername;/// 创建时间（服务端字符串原样）。
 String? get createdAt;/// 当前访问者是否已 star（visitor 视角，DTO 同名字段）。
 bool? get stared;/// 是否置顶。
 bool? get pinned;
/// Create a copy of Repo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepoCopyWith<Repo> get copyWith => _$RepoCopyWithImpl<Repo>(this as Repo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Repo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Repo&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.starCount, _this.starCount) || other.starCount == _this.starCount)&&(identical(other.forkCount, _this.forkCount) || other.forkCount == _this.forkCount)&&(identical(other.openIssueCount, _this.openIssueCount) || other.openIssueCount == _this.openIssueCount)&&(identical(other.openPullRequestCount, _this.openPullRequestCount) || other.openPullRequestCount == _this.openPullRequestCount)&&(identical(other.license, _this.license) || other.license == _this.license)&&(identical(other.lastUpdateUsername, _this.lastUpdateUsername) || other.lastUpdateUsername == _this.lastUpdateUsername)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.stared, _this.stared) || other.stared == _this.stared)&&(identical(other.pinned, _this.pinned) || other.pinned == _this.pinned));
}


@override
int get hashCode {
  final _this = this as Repo;
  return Object.hash(runtimeType,_this.path,_this.name,_this.description,_this.language,_this.starCount,_this.forkCount,_this.openIssueCount,_this.openPullRequestCount,_this.license,_this.lastUpdateUsername,_this.createdAt,_this.stared,_this.pinned);
}

@override
String toString() {
  final _this = this as Repo;
  return 'Repo(path: ${_this.path}, name: ${_this.name}, description: ${_this.description}, language: ${_this.language}, starCount: ${_this.starCount}, forkCount: ${_this.forkCount}, openIssueCount: ${_this.openIssueCount}, openPullRequestCount: ${_this.openPullRequestCount}, license: ${_this.license}, lastUpdateUsername: ${_this.lastUpdateUsername}, createdAt: ${_this.createdAt}, stared: ${_this.stared}, pinned: ${_this.pinned})';
}


}

/// @nodoc
abstract mixin class $RepoCopyWith<$Res>  {
  factory $RepoCopyWith(Repo value, $Res Function(Repo) _then) = _$RepoCopyWithImpl;
@useResult
$Res call({
 String path, String name, String? description, String? language, int starCount, int forkCount, int openIssueCount, int openPullRequestCount, String? license, String? lastUpdateUsername, String? createdAt, bool? stared, bool? pinned
});




}
/// @nodoc
class _$RepoCopyWithImpl<$Res>
    implements $RepoCopyWith<$Res> {
  _$RepoCopyWithImpl(this._self, this._then);

  final Repo _self;
  final $Res Function(Repo) _then;

/// Create a copy of Repo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,Object? description = freezed,Object? language = freezed,Object? starCount = null,Object? forkCount = null,Object? openIssueCount = null,Object? openPullRequestCount = null,Object? license = freezed,Object? lastUpdateUsername = freezed,Object? createdAt = freezed,Object? stared = freezed,Object? pinned = freezed,}) {
  return _then(Repo(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,starCount: null == starCount ? _self.starCount : starCount // ignore: cast_nullable_to_non_nullable
as int,forkCount: null == forkCount ? _self.forkCount : forkCount // ignore: cast_nullable_to_non_nullable
as int,openIssueCount: null == openIssueCount ? _self.openIssueCount : openIssueCount // ignore: cast_nullable_to_non_nullable
as int,openPullRequestCount: null == openPullRequestCount ? _self.openPullRequestCount : openPullRequestCount // ignore: cast_nullable_to_non_nullable
as int,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,lastUpdateUsername: freezed == lastUpdateUsername ? _self.lastUpdateUsername : lastUpdateUsername // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,stared: freezed == stared ? _self.stared : stared // ignore: cast_nullable_to_non_nullable
as bool?,pinned: freezed == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [Repo].
extension RepoPatterns on Repo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Repo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Repo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Repo value)  $default,){
final _that = this;
switch (_that) {
case _Repo():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Repo value)?  $default,){
final _that = this;
switch (_that) {
case _Repo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name,  String? description,  String? language,  int starCount,  int forkCount,  int openIssueCount,  int openPullRequestCount,  String? license,  String? lastUpdateUsername,  String? createdAt,  bool? stared,  bool? pinned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Repo() when $default != null:
return $default(_that.path,_that.name,_that.description,_that.language,_that.starCount,_that.forkCount,_that.openIssueCount,_that.openPullRequestCount,_that.license,_that.lastUpdateUsername,_that.createdAt,_that.stared,_that.pinned);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name,  String? description,  String? language,  int starCount,  int forkCount,  int openIssueCount,  int openPullRequestCount,  String? license,  String? lastUpdateUsername,  String? createdAt,  bool? stared,  bool? pinned)  $default,) {final _that = this;
switch (_that) {
case _Repo():
return $default(_that.path,_that.name,_that.description,_that.language,_that.starCount,_that.forkCount,_that.openIssueCount,_that.openPullRequestCount,_that.license,_that.lastUpdateUsername,_that.createdAt,_that.stared,_that.pinned);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name,  String? description,  String? language,  int starCount,  int forkCount,  int openIssueCount,  int openPullRequestCount,  String? license,  String? lastUpdateUsername,  String? createdAt,  bool? stared,  bool? pinned)?  $default,) {final _that = this;
switch (_that) {
case _Repo() when $default != null:
return $default(_that.path,_that.name,_that.description,_that.language,_that.starCount,_that.forkCount,_that.openIssueCount,_that.openPullRequestCount,_that.license,_that.lastUpdateUsername,_that.createdAt,_that.stared,_that.pinned);case _:
  return null;

}
}

}

/// @nodoc


class _Repo implements Repo {
  const _Repo({required this.path, required this.name, this.description, this.language, this.starCount = 0, this.forkCount = 0, this.openIssueCount = 0, this.openPullRequestCount = 0, this.license, this.lastUpdateUsername, this.createdAt, this.stared, this.pinned});
  

/// 仓库全路径（owner/name），详情与跳转的唯一标识。
@override final  String path;
/// 仓库名（path 的最后一段）。
@override final  String name;
/// 简介。
@override final  String? description;
/// 主语言（`AppLanguageColors` 色条依据）。
@override final  String? language;
/// star 数。
@override@JsonKey() final  int starCount;
/// fork 数。
@override@JsonKey() final  int forkCount;
/// 开放 Issue 数。
@override@JsonKey() final  int openIssueCount;
/// 开放 PR 数。
@override@JsonKey() final  int openPullRequestCount;
/// 开源协议。
@override final  String? license;
/// 最后更新者用户名。
@override final  String? lastUpdateUsername;
/// 创建时间（服务端字符串原样）。
@override final  String? createdAt;
/// 当前访问者是否已 star（visitor 视角，DTO 同名字段）。
@override final  bool? stared;
/// 是否置顶。
@override final  bool? pinned;

/// Create a copy of Repo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepoCopyWith<_Repo> get copyWith => __$RepoCopyWithImpl<_Repo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Repo&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.language, language) || other.language == language)&&(identical(other.starCount, starCount) || other.starCount == starCount)&&(identical(other.forkCount, forkCount) || other.forkCount == forkCount)&&(identical(other.openIssueCount, openIssueCount) || other.openIssueCount == openIssueCount)&&(identical(other.openPullRequestCount, openPullRequestCount) || other.openPullRequestCount == openPullRequestCount)&&(identical(other.license, license) || other.license == license)&&(identical(other.lastUpdateUsername, lastUpdateUsername) || other.lastUpdateUsername == lastUpdateUsername)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.stared, stared) || other.stared == stared)&&(identical(other.pinned, pinned) || other.pinned == pinned));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,name,description,language,starCount,forkCount,openIssueCount,openPullRequestCount,license,lastUpdateUsername,createdAt,stared,pinned);
}

@override
String toString() {
    return 'Repo(path: $path, name: $name, description: $description, language: $language, starCount: $starCount, forkCount: $forkCount, openIssueCount: $openIssueCount, openPullRequestCount: $openPullRequestCount, license: $license, lastUpdateUsername: $lastUpdateUsername, createdAt: $createdAt, stared: $stared, pinned: $pinned)';
}


}

/// @nodoc
abstract mixin class _$RepoCopyWith<$Res> implements $RepoCopyWith<$Res> {
  factory _$RepoCopyWith(_Repo value, $Res Function(_Repo) _then) = __$RepoCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, String? description, String? language, int starCount, int forkCount, int openIssueCount, int openPullRequestCount, String? license, String? lastUpdateUsername, String? createdAt, bool? stared, bool? pinned
});




}
/// @nodoc
class __$RepoCopyWithImpl<$Res>
    implements _$RepoCopyWith<$Res> {
  __$RepoCopyWithImpl(this._self, this._then);

  final _Repo _self;
  final $Res Function(_Repo) _then;

/// Create a copy of Repo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? description = freezed,Object? language = freezed,Object? starCount = null,Object? forkCount = null,Object? openIssueCount = null,Object? openPullRequestCount = null,Object? license = freezed,Object? lastUpdateUsername = freezed,Object? createdAt = freezed,Object? stared = freezed,Object? pinned = freezed,}) {
  return _then(_Repo(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,starCount: null == starCount ? _self.starCount : starCount // ignore: cast_nullable_to_non_nullable
as int,forkCount: null == forkCount ? _self.forkCount : forkCount // ignore: cast_nullable_to_non_nullable
as int,openIssueCount: null == openIssueCount ? _self.openIssueCount : openIssueCount // ignore: cast_nullable_to_non_nullable
as int,openPullRequestCount: null == openPullRequestCount ? _self.openPullRequestCount : openPullRequestCount // ignore: cast_nullable_to_non_nullable
as int,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,lastUpdateUsername: freezed == lastUpdateUsername ? _self.lastUpdateUsername : lastUpdateUsername // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,stared: freezed == stared ? _self.stared : stared // ignore: cast_nullable_to_non_nullable
as bool?,pinned: freezed == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
